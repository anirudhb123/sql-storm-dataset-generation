WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Owner,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, u.DisplayName
),
PopularPosts AS (
    SELECT 
        rp.*,
        pt.Name AS PostTypeName,
        bt.Name AS BestBadge
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostTypes pt ON pt.Id = (SELECT TOP 1 PostTypeId FROM Posts WHERE Id = rp.PostId)
    LEFT JOIN 
        Badges bt ON bt.UserId = rp.Owner AND bt.Class = 1
    WHERE 
        rp.CommentCount > 5 OR rp.Score > 10
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.Score,
    pp.ViewCount,
    pp.Owner,
    pp.CommentCount,
    pp.AnswerCount,
    pp.PostTypeName,
    pp.BestBadge
FROM 
    PopularPosts pp
ORDER BY 
    pp.Score DESC, pp.ViewCount DESC
LIMIT 50;
