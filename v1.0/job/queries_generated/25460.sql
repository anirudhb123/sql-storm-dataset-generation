WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS rank,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names 
    FROM 
        aka_title a
    LEFT JOIN 
        aka_name ak ON a.id = ak.id
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        kind_id,
        aka_names 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        c.name AS company_name,
        ct.kind AS company_type,
        k.keyword AS movie_keyword,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords_list
    FROM 
        TopMovies tm
    LEFT JOIN 
        complete_cast cc ON tm.movie_id = cc.movie_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = tm.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id 
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id 
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = tm.movie_id 
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id 
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year, c.name, ct.kind
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.company_name,
    md.company_type,
    md.keywords_list,
    (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = md.movie_id) AS actor_count
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.title;
