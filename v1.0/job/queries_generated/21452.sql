WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM aka_title a
    LEFT JOIN cast_info c ON a.id = c.movie_id
    GROUP BY a.id, a.title, a.production_year
),
DistinctKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords_list
    FROM movie_keyword m
    JOIN keyword k ON m.keyword_id = k.id
    GROUP BY m.movie_id
),
MaxCastInfo AS (
    SELECT 
        movie_id,
        MAX(nr_order) AS max_order
    FROM cast_info
    GROUP BY movie_id
),
MovieDetails AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(d.keywords_list, 'No Keywords') AS keywords,
        CASE 
            WHEN p.gender IS NULL THEN 'Unknown'
            ELSE p.gender
        END AS predominant_gender
    FROM aka_title m
    LEFT JOIN DistinctKeywords d ON m.id = d.movie_id
    LEFT JOIN (
        SELECT 
            c.movie_id,
            (CASE 
                WHEN COUNT(DISTINCT p.gender) > 1 THEN 'Mixed'
                ELSE MIN(p.gender)
            END) AS gender
        FROM cast_info c
        JOIN name p ON c.person_id = p.id
        GROUP BY c.movie_id
    ) p ON m.id = p.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.keywords,
    CASE 
        WHEN r.rn IS NOT NULL THEN r.rn
        ELSE 'Not Ranked'
    END AS ranking_position,
    (SELECT COUNT(*) FROM aka_name WHERE person_id IN (SELECT DISTINCT c.person_id FROM cast_info c WHERE c.movie_id = md.movie_id)) AS distinct_actors
FROM MovieDetails md
LEFT JOIN RankedMovies r ON md.title = r.title AND md.production_year = r.production_year
WHERE md.keywords IS NOT NULL
ORDER BY md.production_year DESC, ranking_position;
