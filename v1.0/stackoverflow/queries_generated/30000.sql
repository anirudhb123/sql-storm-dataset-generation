WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,  -- Upvotes
        SUM(v.VoteTypeId = 3) AS DownVotes, -- Downvotes
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount,
        COUNT(DISTINCT ph.Id) AS EditHistoryCount,
        p.ViewCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.ViewCount
),
UserPostInteraction AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        pp.PostId,
        pp.Title,
        pp.CommentCount,
        pp.UpVotes,
        pp.DownVotes,
        pp.RelatedPostCount,
        pp.EditHistoryCount,
        pp.ViewCount
    FROM 
        UserReputation ur
    JOIN 
        PopularPosts pp ON ur.UserId = pp.OwnerUserId
    WHERE 
        ur.Reputation > 5000   -- Concentrating on high-reputation users
)
SELECT 
    up.DisplayName AS UserName,
    up.Reputation,
    up.PostId,
    up.Title AS PostTitle,
    up.CommentCount,
    up.UpVotes,
    up.DownVotes,
    up.RelatedPostCount,
    up.EditHistoryCount,
    up.ViewCount,
    CONCAT('User ', up.DisplayName, ' has interacted with a popular post titled: "', up.Title, '" which has ', up.CommentCount, ' comments and ', up.ViewCount, ' views.') AS InteractionSummary
FROM 
    UserPostInteraction up
ORDER BY 
    up.VoteCount DESC, -- Sorting by most engaged posts
    up.CommentCount DESC;
