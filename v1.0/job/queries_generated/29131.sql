WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        kt.kind AS movie_kind,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name SEPARATOR ', ') AS actor_names,
        mc.note AS company_note,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info ca ON a.id = ca.movie_id
    JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    JOIN 
        kind_type kt ON a.kind_id = kt.id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, movie_kind, mc.note
),
FilteredMovies AS (
    SELECT 
        movie_title,
        production_year,
        movie_kind,
        actor_names
    FROM 
        RankedMovies
    WHERE 
        actor_rank <= 3
)
SELECT 
    fm.movie_title,
    fm.production_year,
    fm.movie_kind,
    fm.actor_names,
    COUNT(*) AS related_keywords_count
FROM 
    FilteredMovies fm
JOIN 
    movie_keyword mk ON fm.movie_title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    fm.movie_title, fm.production_year, fm.movie_kind, fm.actor_names
ORDER BY 
    fm.production_year DESC, COUNT(*) DESC;
