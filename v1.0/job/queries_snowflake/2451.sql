
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_count_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mk.keyword_list, 'No Keywords') AS keywords,
        COALESCE(cn.name, 'Unknown Company') AS company_name,
        rm.actor_count_rank
    FROM 
        RankedMovies rm
    LEFT JOIN (
        SELECT 
            mk.movie_id,
            LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keyword_list
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        GROUP BY 
            mk.movie_id
    ) mk ON rm.movie_id = mk.movie_id
    LEFT JOIN (
        SELECT 
            mc.movie_id,
            cn.name
        FROM 
            movie_companies mc
        JOIN 
            company_name cn ON mc.company_id = cn.id
        WHERE 
            mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Production')
    ) cn ON rm.movie_id = cn.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.keywords,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = md.movie_id AND cc.status_id IS NULL) AS missing_cast_count,
    (SELECT AVG(ci.nr_order) FROM cast_info ci WHERE ci.movie_id = md.movie_id) AS avg_order,
    (SELECT MAX(r.role) FROM cast_info ci 
     JOIN role_type r ON ci.role_id = r.id 
     WHERE ci.movie_id = md.movie_id) AS highest_role,
    CASE 
        WHEN md.production_year < 2000 THEN 'Classic'
        WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    MovieDetails md
WHERE 
    md.actor_count_rank <= 5
ORDER BY 
    md.production_year DESC, md.title;
