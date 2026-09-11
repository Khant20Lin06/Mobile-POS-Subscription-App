import { IsNotEmpty, IsOptional, IsString, IsNumber } from 'class-validator';

export class ActivateLicenseDto {
  @IsNotEmpty()
  @IsString()
  shopId: string;

  @IsOptional()
  @IsString()
  shopName?: string;

  @IsNotEmpty()
  @IsString()
  licenseKey: string;
}

export class GenerateLicenseDto {
  @IsOptional()
  @IsString()
  planTier?: string;

  @IsOptional()
  @IsNumber()
  durationDays?: number;
}
