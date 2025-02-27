WITH MovieTitle AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
ActorNames AS (
    SELECT 
        a.person_id,
        a.name,
        a.imdb_index,
        a.surname_pcode
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        complete_cast cc ON ci.movie_id = cc.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
DetailedInfo AS (
    SELECT 
        mv.title AS movie_title,
        mv.production_year,
        an.name AS actor_name,
        an.surname_pcode,
        cd.company_name,
        cd.company_type,
        kw.keyword
    FROM 
        MovieTitle mv
    JOIN 
        ActorNames an ON mv.title_id IN (
            SELECT 
                ci.movie_id 
            FROM 
                cast_info ci 
            WHERE 
                ci.person_id IN (
                    SELECT 
                        a.person_id 
                    FROM 
                        aka_name a 
                    WHERE 
                        a.name IN (SELECT name FROM char_name WHERE imdb_index IS NOT NULL)
                )
        )
    JOIN 
        CompanyDetails cd ON mv.title_id = cd.movie_id
    JOIN 
        movie_info mi ON mv.title_id = mi.movie_id
    JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        (it.info LIKE '%award%' OR it.info LIKE '%nominated%')
)
SELECT 
    movie_title,
    production_year,
    actor_name,
    surname_pcode,
    company_name,
    company_type,
    STRING_AGG(keyword, ', ') AS keywords
FROM 
    DetailedInfo
GROUP BY 
    movie_title, production_year, actor_name, surname_pcode, company_name, company_type
ORDER BY 
    production_year DESC, movie_title;
