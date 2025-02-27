WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2020-01-01'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.PostTypeId
),
TopPosts AS (
    SELECT 
        Title,
        ViewCount,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        COUNT(DISTINCT c.Id) AS CommentsMade
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
EngagedUsers AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.TotalBadges,
        ue.PostsCreated,
        ue.CommentsMade
    FROM 
        UserEngagement ue
    WHERE 
        ue.PostsCreated > 0 OR ue.CommentsMade > 5
    ORDER BY 
        ue.TotalBadges DESC, ue.CommentsMade DESC
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    eu.DisplayName,
    eu.TotalBadges
FROM 
    TopPosts tp
JOIN 
    EngagedUsers eu ON eu.PostsCreated > 0
WHERE 
    EXISTS (
        SELECT 1
        FROM Votes v
        WHERE v.PostId = tp.PostId 
        AND v.UserId IN (SELECT UserId FROM Users WHERE Reputation > 100)
    )
ORDER BY 
    tp.ViewCount DESC
FETCH FIRST 20 ROWS ONLY;
