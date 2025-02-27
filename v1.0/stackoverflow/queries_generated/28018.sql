WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.ViewCount,
        p.Score,
        p.Tags,
        pt.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '365 days'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        Tags,
        PostType
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 5
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.UserId IS NOT NULL) AS VoteCount,
        SUM(b.Class) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.Tags,
    tp.PostType,
    ue.UserId,
    ue.DisplayName AS UserDisplayName,
    ue.CommentCount,
    ue.VoteCount,
    ue.BadgeCount
FROM 
    TopPosts tp
JOIN 
    UserEngagement ue ON tp.PostId IN (
        SELECT DISTINCT c.PostId
        FROM Comments c
        WHERE c.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    )
ORDER BY 
    tp.Score DESC, ue.BadgeCount DESC;
