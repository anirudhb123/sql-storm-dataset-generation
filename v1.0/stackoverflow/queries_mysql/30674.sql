
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 30 DAY
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.PostTypeId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT rp.PostId) AS QuestionsAsked
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        RecentPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.BadgeCount,
        us.QuestionsAsked,
        @rank := @rank + 1 AS Rank
    FROM 
        UserStats us, 
        (SELECT @rank := 0) r
    ORDER BY 
        us.Reputation DESC, us.BadgeCount DESC
)

SELECT 
    tu.Rank,
    tu.DisplayName,
    tu.Reputation,
    tu.BadgeCount,
    tu.QuestionsAsked,
    COALESCE(rp.CommentCount, 0) AS LastMonthCommentCount,
    COALESCE(rp.UpVoteCount, 0) AS LastMonthUpVoteCount,
    COALESCE(rp.DownVoteCount, 0) AS LastMonthDownVoteCount
FROM 
    TopUsers tu
LEFT JOIN 
    RecentPosts rp ON tu.UserId = rp.OwnerUserId
WHERE 
    tu.Rank <= 10  
ORDER BY 
    tu.Rank;
