import from "radix-ui" { Progress as ProgressPrimitive }
import from ...lib.utils { cn }

def:pub Progress(props: any) -> JsxElement {
    value = props["value"] or 0;
    translateX = 100 - value;
    return
        <ProgressPrimitive.Root
            {**props}
            data-slot="progress"
            className={cn(
                "bg-muted h-1.5 rounded-full relative flex w-full items-center overflow-x-hidden",
                props["className"]
            )}
        >
            <ProgressPrimitive.Indicator
                data-slot="progress-indicator"
                className="bg-primary size-full flex-1 transition-all"
                style={{"transform": "translateX(-" + String(translateX) + "%)"}}
            />
        </ProgressPrimitive.Root>;
}
