WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS title_rank,
        COALESCE(SUM(CASE WHEN tt.kind_id = 1 THEN 1 ELSE 0 END), 0) AS total_feature_film,
        COUNT(DISTINCT ci.person_id) AS total_cast_members
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        kind_type kt ON t.kind_id = kt.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    RIGHT JOIN 
        title tt ON tt.id = t.id
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        rt.title,
        rt.production_year,
        rt.total_cast_members,
        rt.total_feature_film
    FROM 
        RankedTitles rt
    WHERE 
        rt.title_rank <= 3 AND (rt.total_cast_members > 5 OR rt.total_feature_film > 0)
),
SelectedMovies AS (
    SELECT 
        tm.*,
        CASE 
            WHEN tm.total_cast_members IS NULL THEN 'N/A'
            ELSE concat('Cast Members: ', tm.total_cast_members)
        END AS cast_info,
        current_date - interval '1 year' * (tm.production_year - 2023) AS years_since_release
    FROM 
        TopMovies tm
)
SELECT 
    sm.title,
    sm.production_year,
    sm.cast_info,
    sm.years_since_release,
    kt.kind AS film_type
FROM 
    SelectedMovies sm
LEFT JOIN 
    kind_type kt ON sm.total_feature_film > 0 AND kt.id = 1 -- Assuming feature films have id = 1
WHERE 
    sm.years_since_release >= 0 
    AND sm.years_since_release < 10
ORDER BY 
    sm.production_year DESC, 
    sm.total_cast_members DESC;
