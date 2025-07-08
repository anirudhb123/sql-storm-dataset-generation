
WITH MovieData AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COALESCE(fo.name, 'Unknown') AS first_oscillator,
        COALESCE(lo.name, 'Unknown') AS last_oscillator,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_year
    FROM aka_title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    LEFT JOIN aka_name fo ON c.person_id = fo.person_id AND fo.name_pcode_cf IS NOT NULL
    LEFT JOIN aka_name lo ON c.person_id = lo.person_id AND lo.name_pcode_nf IS NOT NULL
    WHERE 
        t.production_year IS NOT NULL 
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id, fo.name, lo.name
), 
HighCastMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.total_cast,
        CASE 
            WHEN md.total_cast > 10 THEN 'High'
            WHEN md.total_cast BETWEEN 5 AND 10 THEN 'Medium'
            ELSE 'Low'
        END AS cast_size_category
    FROM MovieData md
    WHERE md.rank_by_year <= 5 
),

KeywordInfo AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)

SELECT 
    hcm.title,
    hcm.production_year,
    hcm.cast_size_category,
    COALESCE(ki.keywords, 'No keywords') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY hcm.cast_size_category ORDER BY hcm.total_cast DESC) AS rank_within_category,
    (SELECT AVG(total_cast) FROM HighCastMovies) AS avg_cast_size
FROM HighCastMovies hcm
LEFT JOIN KeywordInfo ki ON hcm.movie_id = ki.movie_id
WHERE 
    hcm.production_year > 2000 
    AND hcm.cast_size_category = 'High'
    AND EXISTS (SELECT 1 FROM complete_cast cc WHERE cc.movie_id = hcm.movie_id AND cc.status_id IS NULL)
ORDER BY hcm.production_year DESC, hcm.total_cast DESC;
