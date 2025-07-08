
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t 
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year IS NOT NULL
        AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%action%' OR keyword LIKE '%drama%')
),
MovieCast AS (
    SELECT 
        cm.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names
    FROM 
        complete_cast cm
    JOIN 
        cast_info ci ON cm.movie_id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        cm.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        mc.total_cast,
        mc.cast_names
    FROM 
        RankedMovies rm
    JOIN 
        MovieCast mc ON rm.movie_id = mc.movie_id
    WHERE 
        rm.rank <= 5 
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.total_cast,
    md.cast_names,
    k.keyword,
    ct.kind AS company_type
FROM 
    MovieDetails md
JOIN 
    movie_info mi ON md.movie_id = mi.movie_id
JOIN 
    keyword k ON mi.info LIKE '%' || k.keyword || '%'
JOIN 
    movie_companies mc ON md.movie_id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    ct.kind IN ('Distributor', 'Production') 
ORDER BY 
    md.production_year DESC, 
    md.movie_id;
