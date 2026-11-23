package in.ashokit.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DashboardResponseDto {
	
	private Integer totalEnqs;
	private Integer openEnqs;
	private Integer enrolledEnqs;
	private Integer lostEnqs;
	private Double conversionRate;

}
