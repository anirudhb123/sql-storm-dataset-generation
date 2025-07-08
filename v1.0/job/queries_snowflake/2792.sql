
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
FilmDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names,
        COALESCE(MAX(CASE WHEN it.info = 'Budget' THEN m_info.info END), 'N/A') AS budget_info,
        COALESCE(MAX(CASE WHEN it.info = 'Runtime' THEN m_info.info END), 'N/A') AS runtime_info
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON ci.movie_id = (
            SELECT MAX(ci_inner.movie_id) 
            FROM cast_info ci_inner 
            WHERE ci_inner.person_id IN (SELECT person_id FROM aka_name WHERE name IS NOT NULL)
        )
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_info m_info ON tm.title = m_info.info AND m_info.note IS NULL
    LEFT JOIN 
        info_type it ON m_info.info_type_id = it.id
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    fd.title,
    fd.production_year,
    fd.actor_names,
    fd.budget_info,
    fd.runtime_info
FROM 
    FilmDetails fd
WHERE 
    fd.budget_info IS NOT NULL
ORDER BY 
    fd.production_year DESC, fd.title;
