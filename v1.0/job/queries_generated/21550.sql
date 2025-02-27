WITH Recursive ActorTitles AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        a.md5sum,
        t.title AS title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS title_rank 
    FROM
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        c.nr_order IS NOT NULL
),
AggregatedData AS (
    SELECT 
        actor_id,
        actor_name,
        COUNT(title) AS title_count,
        STRING_AGG(title, '; ') AS all_titles,
        MIN(production_year) AS first_year,
        MAX(production_year) AS last_year
    FROM 
        ActorTitles
    WHERE 
        title_rank <= 5  -- Limit to the last 5 titles
    GROUP BY 
        actor_id, actor_name
),
IndustryInsights AS (
    SELECT 
        ad.actor_name,
        ad.title_count,
        ad.all_titles,
        ad.first_year,
        ad.last_year,
        CASE
            WHEN ad.last_year - ad.first_year > 10 THEN 'Veteran'
            WHEN ad.title_count >= 20 THEN 'Prolific'
            ELSE 'Novice'
        END AS experience_level
    FROM 
        AggregatedData ad
),
CompanyMovieCounts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
ComplexQuery AS (
    SELECT 
        i.actor_name,
        i.title_count,
        i.all_titles,
        i.first_year,
        i.last_year,
        i.experience_level,
        cmc.company_count,
        -- Conditional expression for average year range
        CASE 
            WHEN i.last_year - i.first_year > 0 THEN 
                (i.last_year + i.first_year) / 2 
            ELSE 
                NULL 
        END AS average_year_range
    FROM 
        IndustryInsights i
    LEFT JOIN 
        CompanyMovieCounts cmc ON cmc.movie_id IN (
            SELECT DISTINCT movie_id 
            FROM cast_info 
            WHERE person_id = i.actor_id
        )
    WHERE 
        (i.experience_level = 'Veteran' OR i.experience_level = 'Prolific') 
        AND (cmc.company_count IS NOT NULL OR i.actor_id % 2 = 0)  -- Edge case: odd/even actor IDs
)
SELECT 
    actor_name,
    title_count,
    all_titles,
    first_year,
    last_year,
    experience_level,
    COALESCE(company_count, 0) AS company_count,
    average_year_range
FROM 
    ComplexQuery
WHERE 
    (last_year IS NULL OR last_year >= 2000)  -- Selecting based on null year condition
ORDER BY 
    title_count DESC, last_year ASC;
