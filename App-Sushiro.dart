import { useCallback, useEffect, useState } from 'react';
import { Delete, Minus, Plus, QrCode, RotateCcw, Trash2 } from 'lucide-react';
import {
  INITIAL_COUNTS,
  PLATE_TIERS,
  calculateBill,
  formatBaht,
  type PlateCounts,
  type PlateId,
} from './data/plates';
import { PlateIcon } from './components/PlateIcon';
import { CheckoutSheet } from './components/CheckoutSheet';

type DisplayTab = 'RESULT' | 'PRICE' | 'AMOUNT';

export default function App() {
  const [counts, setCounts] = useState<PlateCounts>(INITIAL_COUNTS);
  const [selectedPlate, setSelectedPlate] = useState<PlateId>('white');
  const [activeTab, setActiveTab] = useState<DisplayTab>('RESULT');
  const [includeServiceCharge, setIncludeServiceCharge] = useState<boolean>(true);
  const [replaceOnNextDigit, setReplaceOnNextDigit] = useState<boolean>(true);
  const [isCheckoutOpen, setIsCheckoutOpen] = useState<boolean>(false);
  const [emptyHint, setEmptyHint] = useState<boolean>(false);

  const { subtotal, total, totalPlates } = calculateBill(
    counts,
    includeServiceCharge
  );

  const activeTier =
    PLATE_TIERS.find((t) => t.id === selectedPlate) ?? PLATE_TIERS[0];

  const handleSelectPlate = useCallback((id: PlateId) => {
    setSelectedPlate(id);
    setReplaceOnNextDigit(true);
    setEmptyHint(false);
  }, []);

  const handleTapPlateButton = useCallback((id: PlateId) => {
    setEmptyHint(false);
    setSelectedPlate(id);
    setReplaceOnNextDigit(true);
    setCounts((prev) => ({
      ...prev,
      [id]: Math.min(999, (prev[id] || 0) + 1),
    }));
  }, []);

  const handleDigitPress = useCallback(
    (digit: string) => {
      setEmptyHint(false);
      setCounts((prev) => {
        const current = prev[selectedPlate] || 0;
        let nextVal: number;
        if (replaceOnNextDigit || current === 0) {
          nextVal = Number(digit);
        } else {
          nextVal = Math.min(999, Number(`${current}${digit}`));
        }
        return { ...prev, [selectedPlate]: nextVal };
      });
      setReplaceOnNextDigit(false);
    },
    [selectedPlate, replaceOnNextDigit]
  );

  const handleBackspace = useCallback(() => {
    setEmptyHint(false);
    setCounts((prev) => {
      const current = prev[selectedPlate] || 0;
      if (current === 0) return prev;
      const str = String(current);
      const nextVal = str.length <= 1 ? 0 : Number(str.slice(0, -1));
      return { ...prev, [selectedPlate]: nextVal };
    });
    setReplaceOnNextDigit(false);
  }, [selectedPlate]);

  const handleStepPlate = useCallback((id: PlateId, delta: number) => {
    setEmptyHint(false);
    setSelectedPlate(id);
    setReplaceOnNextDigit(true);
    setCounts((prev) => ({
      ...prev,
      [id]: Math.max(0, Math.min(999, (prev[id] || 0) + delta)),
    }));
  }, []);

  const handleClearSelectedPlate = useCallback(() => {
    setEmptyHint(false);
    setCounts((prev) => ({
      ...prev,
      [selectedPlate]: 0,
    }));
    setReplaceOnNextDigit(true);
  }, [selectedPlate]);

  const handleResetAll = useCallback(() => {
    setCounts(INITIAL_COUNTS);
    setReplaceOnNextDigit(true);
    setEmptyHint(false);
  }, []);

  const handleOpenCheckout = useCallback(() => {
    if (totalPlates === 0) {
      setEmptyHint(true);
      return;
    }
    setEmptyHint(false);
    setIsCheckoutOpen(true);
  }, [totalPlates]);

  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      if (isCheckoutOpen) {
        if (e.key === 'Escape') setIsCheckoutOpen(false);
        return;
      }
      if (e.key >= '0' && e.key <= '9') {
        e.preventDefault();
        handleDigitPress(e.key);
      } else if (e.key === 'Backspace') {
        e.preventDefault();
        handleBackspace();
      } else if (e.key === 'ArrowRight') {
        e.preventDefault();
        const idx = PLATE_TIERS.findIndex((t) => t.id === selectedPlate);
        handleSelectPlate(PLATE_TIERS[(idx + 1) % PLATE_TIERS.length].id);
      } else if (e.key === 'ArrowLeft') {
        e.preventDefault();
        const idx = PLATE_TIERS.findIndex((t) => t.id === selectedPlate);
        handleSelectPlate(
          PLATE_TIERS[(idx - 1 + PLATE_TIERS.length) % PLATE_TIERS.length].id
        );
      } else if (e.key === 'Enter' && totalPlates > 0) {
        e.preventDefault();
        handleOpenCheckout();
      }
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [
    isCheckoutOpen,
    selectedPlate,
    totalPlates,
    handleDigitPress,
    handleBackspace,
    handleSelectPlate,
    handleOpenCheckout,
  ]);

  return (
    <div className="min-h-dvh bg-[#000000] text-zinc-50 flex items-center justify-center sm:p-4">
      <main className="flex h-dvh w-full max-w-[420px] flex-col justify-between px-4 pt-3 pb-5 sm:h-auto sm:min-h-[720px] sm:rounded-3xl sm:border sm:border-zinc-800/80 sm:bg-[#050507] sm:p-6">
        {/* 1. Top 5 Plate Counter Badges */}
        <div className="grid grid-cols-5 gap-1.5">
          {PLATE_TIERS.map((tier) => {
            const count = counts[tier.id] || 0;
            const isSelected = selectedPlate === tier.id;
            return (
              <button
                key={tier.id}
                type="button"
                onClick={() => handleSelectPlate(tier.id)}
                aria-label={`${tier.colorNameTh} ${tier.price} บาท จำนวน ${count} จาน`}
                className={`flex min-h-[38px] overflow-hidden rounded-md border transition-all ${
                  isSelected
                    ? 'border-white ring-1 ring-white/80'
                    : 'border-zinc-700/80 hover:border-zinc-500'
                }`}
              >
                <span className="relative flex flex-1 items-center justify-center bg-white px-1 py-1 text-[11px] font-bold text-zinc-950 font-mono-num">
                  <span
                    className={`absolute inset-y-0 left-0 w-1 ${tier.accentBarClass}`}
                    aria-hidden="true"
                  />
                  <span className="pl-0.5">{tier.priceLabel}</span>
                </span>
                <span className="flex min-w-[24px] items-center justify-center bg-black px-1.5 py-1 text-xs font-bold text-white font-mono-num">
                  {count}
                </span>
              </button>
            );
          })}
        </div>

        {/* 2. RESULT | PRICE | AMOUNT Tabs & Big Display */}
        <div className="flex flex-1 flex-col justify-center py-4">
          <div
            className="flex items-center justify-end gap-5 text-xs font-bold tracking-wide"
            role="tablist"
            aria-label="โหมดแสดงผล"
          >
            {(['RESULT', 'PRICE', 'AMOUNT'] as const).map((tab) => {
              const isActive = activeTab === tab;
              return (
                <button
                  key={tab}
                  type="button"
                  role="tab"
                  aria-selected={isActive}
                  onClick={() => setActiveTab(tab)}
                  className={`min-h-[36px] transition-colors whitespace-nowrap shrink-0 ${
                    isActive
                      ? 'text-white'
                      : 'text-zinc-500 hover:text-zinc-300'
                  }`}
                >
                  {tab}
                </button>
              );
            })}
          </div>

          <div className="mt-2 flex flex-col items-end text-right">
            {activeTab === 'RESULT' && (
              <>
                <div className="font-mono-num text-6xl font-bold tracking-tight text-white sm:text-7xl">
                  {formatBaht(total)}
                </div>
                <p className="mt-2 text-sm text-zinc-400 font-mono-num">
                  {includeServiceCharge
                    ? `${formatBaht(subtotal)} w/o 10%`
                    : 'ไม่คิดค่าบริการ 10%'}
                </p>
              </>
            )}

            {activeTab === 'PRICE' && (
              <>
                <div className="font-mono-num text-6xl font-bold tracking-tight text-white sm:text-7xl">
                  {formatBaht(subtotal)}
                </div>
                <p className="mt-2 text-sm text-zinc-400">
                  {activeTier.colorNameTh} {activeTier.priceLabel}
                </p>
              </>
            )}

            {activeTab === 'AMOUNT' && (
              <>
                <div className="font-mono-num text-6xl font-bold tracking-tight text-white sm:text-7xl">
                  {totalPlates}
                </div>
                <p className="mt-2 text-sm text-zinc-400">
                  จำนวนจานทั้งหมด
                </p>
              </>
            )}
          </div>
        </div>

        {/* 3. Controls & Keypad (Bottom Thumb Zone) */}
        <div className="space-y-3">
          {/* Compact selected plate & quick +/- */}
          <div className="flex items-center justify-between px-1">
            <div className="flex items-center gap-2 text-xs text-zinc-400">
              <PlateIcon tier={activeTier} size={18} />
              <span className="font-medium text-zinc-200">
                {activeTier.colorNameTh}
              </span>
              <span className="font-mono-num text-zinc-500">
                {activeTier.priceLabel}
              </span>
            </div>

            <div className="flex items-center gap-1.5">
              <button
                type="button"
                onClick={handleClearSelectedPlate}
                disabled={(counts[selectedPlate] || 0) === 0}
                aria-label={`ลบจำนวน${activeTier.colorNameTh}ทั้งหมด`}
                className="flex h-9 items-center justify-center gap-1 rounded-lg border border-zinc-800 bg-zinc-900 px-2.5 text-xs font-semibold text-red-400 transition-colors hover:bg-zinc-800 active:scale-95 disabled:opacity-35 disabled:pointer-events-none"
              >
                <Trash2 className="h-3.5 w-3.5" />
                <span>ลบ</span>
              </button>
              <button
                type="button"
                onClick={() => handleStepPlate(selectedPlate, -1)}
                aria-label={`ลดจำนวน${activeTier.colorNameTh}`}
                className="flex h-9 w-9 items-center justify-center rounded-lg border border-zinc-800 bg-zinc-900 text-zinc-300 active:scale-95"
              >
                <Minus className="h-3.5 w-3.5" />
              </button>
              <span className="font-mono-num min-w-[26px] text-center text-sm font-bold text-white">
                {counts[selectedPlate] || 0}
              </span>
              <button
                type="button"
                onClick={() => handleStepPlate(selectedPlate, 1)}
                aria-label={`เพิ่มจำนวน${activeTier.colorNameTh}`}
                className="flex h-9 w-9 items-center justify-center rounded-lg border border-zinc-800 bg-zinc-900 text-white active:scale-95"
              >
                <Plus className="h-3.5 w-3.5" />
              </button>
            </div>
          </div>

          {/* 5 Plate Color Selector Buttons (tap to select & add +1) */}
          <div
            className="grid grid-cols-5 gap-1.5"
            role="group"
            aria-label="กดเลือกสีจานซูชิเพื่อเพิ่มจำนวน"
          >
            {PLATE_TIERS.map((tier) => {
              const isSelected = selectedPlate === tier.id;
              return (
                <button
                  key={tier.id}
                  type="button"
                  onClick={() => handleTapPlateButton(tier.id)}
                  aria-label={`เพิ่ม ${tier.colorNameTh} ${tier.price} บาท`}
                  className={`flex min-h-[46px] items-center justify-center gap-1 rounded-xl border px-1 transition-all active:scale-95 ${
                    isSelected
                      ? 'border-white bg-zinc-900 text-white'
                      : 'border-zinc-800 bg-zinc-950 text-zinc-300 hover:border-zinc-700'
                  }`}
                >
                  <PlateIcon tier={tier} size={16} className="shrink-0" />
                  <span className="font-mono-num text-[11px] font-bold sm:text-xs">
                    {tier.priceLabel}
                  </span>
                </button>
              );
            })}
          </div>

          {/* 3x4 Numeric Keypad */}
          <div className="grid grid-cols-3 gap-1.5 pt-1">
            {['7', '8', '9', '4', '5', '6', '1', '2', '3'].map((digit) => (
              <button
                key={digit}
                type="button"
                onClick={() => handleDigitPress(digit)}
                className="font-mono-num flex min-h-[54px] items-center justify-center rounded-xl text-xl font-bold text-white transition-colors hover:bg-zinc-900 active:bg-zinc-800"
              >
                {digit}
              </button>
            ))}

            <button
              type="button"
              onClick={() => setIncludeServiceCharge((v) => !v)}
              aria-pressed={includeServiceCharge}
              aria-label="เปิดหรือปิดค่าบริการ 10%"
              className={`font-mono-num flex min-h-[54px] items-center justify-center rounded-xl text-sm font-bold transition-colors hover:bg-zinc-900 active:bg-zinc-800 ${
                includeServiceCharge ? 'text-white' : 'text-zinc-600'
              }`}
            >
              +10%
            </button>

            <button
              type="button"
              onClick={() => handleDigitPress('0')}
              className="font-mono-num flex min-h-[54px] items-center justify-center rounded-xl text-xl font-bold text-white transition-colors hover:bg-zinc-900 active:bg-zinc-800"
            >
              0
            </button>

            <button
              type="button"
              onClick={handleBackspace}
              aria-label="ลบตัวเลข"
              className="flex min-h-[54px] flex-col items-center justify-center gap-0.5 rounded-xl text-zinc-300 transition-colors hover:bg-zinc-900 active:bg-zinc-800"
            >
              <Delete className="h-5 w-5" />
              <span className="text-[10px] font-medium leading-none text-zinc-400">
                ลบเลข
              </span>
            </button>
          </div>

          {emptyHint && (
            <p
              role="status"
              className="text-center text-xs font-medium text-amber-400"
            >
              กรุณาใส่จำนวนจานก่อนเรียกเก็บเงิน
            </p>
          )}

          {/* Action Row: Reset & Call for Bill */}
          <div className="flex items-center gap-2 pt-1">
            <button
              type="button"
              onClick={handleResetAll}
              disabled={totalPlates === 0}
              aria-label="ลบทั้งหมด"
              className="flex min-h-[50px] items-center justify-center gap-1.5 rounded-xl border border-zinc-800 bg-zinc-950 px-3.5 text-xs font-semibold text-zinc-300 transition-colors hover:bg-zinc-900 disabled:opacity-40"
            >
              <RotateCcw className="h-4 w-4" />
              <span>ลบทั้งหมด</span>
            </button>

            <button
              type="button"
              onClick={handleOpenCheckout}
              className="flex min-h-[50px] flex-1 items-center justify-center gap-2 rounded-xl bg-white px-4 text-sm font-bold text-zinc-950 transition-transform hover:bg-zinc-100 active:scale-[0.98]"
            >
              <QrCode className="h-4 w-4 shrink-0" />
              <span>เรียกเก็บเงิน</span>
              <span className="font-mono-num text-zinc-700">
                {formatBaht(total)} ฿
              </span>
            </button>
          </div>
        </div>
      </main>

      <CheckoutSheet
        isOpen={isCheckoutOpen}
        onClose={() => setIsCheckoutOpen(false)}
        counts={counts}
        includeServiceCharge={includeServiceCharge}
        onResetOrder={handleResetAll}
      />
    </div>
  );
}
