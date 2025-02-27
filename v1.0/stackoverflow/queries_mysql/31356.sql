
WITH RECURSIVE UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostsWithStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), 0) AS AcceptedAnswerId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6)
    GROUP BY 
        p.Id, p.Title, p.Score, AcceptedAnswerId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        ub.BadgeCount,
        @rownum := @rownum + 1 AS Rank
    FROM 
        Users u,
        (SELECT @rownum := 0) r,
        UserBadgeCounts ub 
    WHERE 
        u.Id = ub.UserId
    ORDER BY 
        u.Reputation DESC
)
SELECT 
    tu.Rank,
    tu.DisplayName,
    tu.Reputation,
    ph.PostId,
    ph.Title,
    ph.Score,
    ph.AcceptedAnswerId,
    ph.UpVotes,
    ph.DownVotes,
    ph.CommentCount,
    ph.EditCount,
    CASE 
        WHEN ph.Score > 0 THEN 'Positive'
        WHEN ph.Score < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment
FROM 
    PostsWithStats ph
JOIN 
    TopUsers tu ON ph.AcceptedAnswerId = tu.Id
WHERE 
    (ph.UpVotes - ph.DownVotes) > 10
ORDER BY 
    tu.Rank ASC,
    ph.Score DESC
LIMIT 10 OFFSET 0;
