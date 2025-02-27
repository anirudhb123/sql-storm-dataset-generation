WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) FILTER (WHERE c.Id IS NOT NULL) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        COALESCE(rp.CommentCount, 0) AS TotalComments,
        rp.ViewCount,
        rp.Score,
        rp.RankScore
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 5
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounties,
        COUNT(v.Id) AS VoteCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.TotalComments,
    ue.DisplayName AS ActiveUser,
    COALESCE(ue.TotalBounties, 0) AS TotalBounties,
    COALESCE(ue.VoteCount, 0) AS TotalVotes
FROM 
    TopPosts tp
FULL OUTER JOIN 
    UserEngagement ue ON tp.PostId = ue.UserId
WHERE 
    tp.ViewCount > 100 
    OR ue.TotalBounties IS NOT NULL
ORDER BY 
    tp.ViewCount DESC, 
    ue.TotalVotes DESC;
