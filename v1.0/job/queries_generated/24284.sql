WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS role_rank,
        COALESCE(cm.name, 'Unknown') AS company_name,
        STRING_AGG(ka.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cm ON mc.company_id = cm.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        t.id, t.title, t.production_year, cm.name
),
FilteredRankedMovies AS (
    SELECT 
        *,
        CASE 
            WHEN role_rank = 1 THEN 'Top Cast'
            WHEN role_rank IS NULL THEN 'No Cast'
            ELSE 'Supporting Cast'
        END AS cast_type
    FROM 
        RankedMovies
    WHERE 
        production_year > 2000
),
FinalResults AS (
    SELECT 
        fr.movie_id,
        fr.title,
        fr.production_year,
        fr.company_name,
        fr.cast_names,
        fr.keywords,
        COUNT(*) FILTER (WHERE fr.cast_type = 'Top Cast') AS top_cast_count
    FROM 
        FilteredRankedMovies fr
    GROUP BY 
        fr.movie_id, fr.title, fr.production_year, fr.company_name, fr.cast_names, fr.keywords
    HAVING 
        COUNT(*) >= 2
)

SELECT 
    frh.movie_id, 
    frh.title,
    frh.production_year,
    frh.company_name, 
    frh.cast_names, 
    frh.keywords,
    frh.top_cast_count,
    CASE
        WHEN frh.top_cast_count > 3 THEN 'Highly Rated'
        ELSE 'Moderately Rated'
    END AS rating_category
FROM 
    FinalResults frh
ORDER BY 
    frh.production_year DESC, frh.top_cast_count DESC
LIMIT 10;
