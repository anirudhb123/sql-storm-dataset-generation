WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
PostVoteStats AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
TopPostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.Level,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        COALESCE(b.GoldBadges, 0) AS GoldBadges,
        COALESCE(b.SilverBadges, 0) AS SilverBadges,
        COALESCE(b.BronzeBadges, 0) AS BronzeBadges,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        RecursivePostHierarchy ph ON p.Id = ph.Id
    LEFT JOIN 
        PostVoteStats vs ON p.Id = vs.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UserBadges b ON u.Id = b.UserId
    WHERE 
        p.Score > 0 /* considering only posts with a score greater than 0 */
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Level,
    pd.UpVotes,
    pd.DownVotes,
    pd.GoldBadges,
    pd.SilverBadges,
    pd.BronzeBadges,
    pd.CommentCount
FROM 
    TopPostDetails pd
WHERE 
    pd.UpVotes - pd.DownVotes > 10 /* selecting posts with more than 10 net positive votes */
ORDER BY 
    pd.UpVotes DESC;
