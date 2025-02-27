WITH MovieCast AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        c.person_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS cast_order,
        COUNT(*) OVER (PARTITION BY t.id) AS total_cast
    FROM title t
    INNER JOIN cast_info c ON t.id = c.movie_id
    INNER JOIN aka_name a ON c.person_id = a.person_id
    WHERE t.production_year > 2000
      AND a.name IS NOT NULL
),
MoviesWithKeywords AS (
    SELECT 
        m.title_id,
        m.title,
        m.production_year,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM MovieCast m
    LEFT JOIN movie_keyword mk ON m.title_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY m.title_id, m.title, m.production_year
),
RankedMovies AS (
    SELECT
        mwk.title,
        mwk.production_year,
        mwk.keywords,
        mc.person_id,
        mc.actor_name,
        mc.cast_order,
        mc.total_cast,
        RANK() OVER (ORDER BY mwk.production_year DESC, mc.total_cast ASC) AS movie_rank
    FROM MoviesWithKeywords mwk
    JOIN MovieCast mc ON mwk.title_id = mc.title_id
),
HighRankedMovies AS (
    SELECT
        *,
        CASE 
            WHEN total_cast > 5 THEN 'Ensemble Cast'
            ELSE 'Limited Cast'
        END AS cast_type
    FROM RankedMovies
    WHERE movie_rank <= 100
)
SELECT 
    hr.title,
    hr.production_year,
    hr.keywords,
    hr.actor_name,
    hr.cast_order,
    hr.total_cast,
    hr.cast_type,
    COALESCE(NULLIF(hr.keywords, ''), 'No Keywords') AS adjusted_keywords,
    (SELECT COUNT(DISTINCT c.movie_id) 
     FROM cast_info c 
     WHERE c.person_id = hr.person_id 
       AND EXISTS (SELECT 1 FROM title t WHERE t.id = c.movie_id AND t.production_year < 2000)
    ) AS pre_2000_appearances
FROM HighRankedMovies hr
ORDER BY hr.production_year DESC, hr.movie_rank;
