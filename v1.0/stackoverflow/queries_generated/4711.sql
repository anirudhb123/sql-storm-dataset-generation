WITH UserScoreSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.UpVotes,
        u.DownVotes,
        (u.UpVotes - u.DownVotes) AS NetVotes,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PopularTags AS (
    SELECT 
        Tags,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        Tags
    HAVING 
        COUNT(DISTINCT p.Id) > 5
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.ViewCount,
        p.CommentCount,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
)

SELECT 
    us.Rank,
    us.DisplayName,
    us.Reputation,
    us.BadgeCount,
    pt.Tags,
    pt.PostCount,
    pt.TotalViews,
    pe.Title,
    pe.ViewCount,
    pe.CommentCount,
    pe.UpVotes,
    pe.DownVotes
FROM 
    UserScoreSummary us
JOIN 
    PostEngagement pe ON us.UserId = pe.OwnerUserId
JOIN 
    PopularTags pt ON pt.Tags ILIKE ANY (STRING_TO_ARRAY(pe.Title, ' ')) -- Assuming tags are part of title
WHERE 
    us.Reputation > 1000
    AND pe.ViewRank = 1
ORDER BY 
    us.Reputation DESC, 
    pt.TotalViews DESC
LIMIT 10;
