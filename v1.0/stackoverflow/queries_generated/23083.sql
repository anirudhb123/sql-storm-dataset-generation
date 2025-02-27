WITH UserReputation AS (
    SELECT 
        Id, 
        Reputation, 
        CreationDate,
        DisplayName, 
        NULLIF(WebsiteUrl, '') AS CleanWebsiteUrl,
        EXTRACT(YEAR FROM AGE(CreationDate)) AS AccountAge,
        UpVotes - DownVotes AS NetVotes
    FROM 
        Users
    WHERE 
        Reputation > 0
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), 0) AS AcceptedAnswerId,
        CASE 
            WHEN p.LastActivityDate < p.CreationDate + INTERVAL '1 year' THEN 'New'
            WHEN p.LastActivityDate BETWEEN p.CreationDate + INTERVAL '1 year' AND p.CreationDate + INTERVAL '2 years' THEN 'Moderate'
            ELSE 'Old' 
        END AS ActivityStatus
    FROM 
        Posts p
    WHERE 
        p.ViewCount > 100 AND (p.Score IS NULL OR p.Score > 0)
),
PostStats AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.ViewCount,
        pd.Score,
        pd.ActivityStatus,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY pd.ActivityStatus ORDER BY pd.Score DESC) AS PostRank
    FROM 
        PostDetails pd
    LEFT JOIN 
        Comments c ON pd.PostId = c.PostId 
    LEFT JOIN 
        Votes v ON pd.PostId = v.PostId
    GROUP BY 
        pd.PostId, pd.Title, pd.ViewCount, pd.Score, pd.ActivityStatus
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS Badges,
        COUNT(b.Class) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Class) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Class) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    u.NetVotes,
    COALESCE(ub.Badges, 'No Badges') AS Badges,
    ps.PostId,
    ps.Title AS PostTitle,
    ps.ViewCount AS PostViews,
    ps.Score AS PostScore,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.ActivityStatus,
    CASE 
        WHEN ps.PostRank IS NULL THEN 'No Rank'
        ELSE CAST(ps.PostRank AS VARCHAR)
    END AS PostRank
FROM 
    UserReputation u
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostStats ps ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId LIMIT 1)
WHERE 
    u.Reputation > (SELECT AVG(Reputation) FROM Users) 
    AND ps.ActivityStatus IN ('New', 'Moderate')
    AND (u.CleanWebsiteUrl IS NOT NULL OR u.Location IS NOT NULL)
ORDER BY 
    u.Reputation DESC, 
    ps.ViewCount DESC
LIMIT 100;
