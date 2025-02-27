WITH RankedPostTitles AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS TitleRank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        pt.Name = 'Question' 
        AND p.Score IS NOT NULL
),
TopUserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
    HAVING 
        COUNT(b.Id) > 0
),
PostCommentsAggregation AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, '; ' ORDER BY c.CreationDate) AS AllComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    p.PostId,
    p.Title,
    pp.TitleRank,
    ub.BadgeCount,
    ub.BadgeNames,
    pc.CommentCount,
    pc.AllComments
FROM 
    RankedPostTitles pp
JOIN 
    Posts p ON pp.PostId = p.Id
JOIN 
    TopUserBadges ub ON p.OwnerUserId = ub.UserId
JOIN 
    PostCommentsAggregation pc ON p.Id = pc.PostId
WHERE 
    pp.TitleRank <= 5
ORDER BY 
    pp.TitleRank, ub.BadgeCount DESC;
