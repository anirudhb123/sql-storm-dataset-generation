WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only take questions as starting points
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
),
PostVoteStatistics AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
UserWithBadges AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
SelectedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        PH.UpVotes,
        PH.DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        PostVoteStatistics PH ON p.Id = PH.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'  -- Only get recent posts
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, PH.UpVotes, PH.DownVotes
),
PostAnalysis AS (
    SELECT 
        sp.*,
        CASE 
            WHEN sp.UpVotes > sp.DownVotes THEN 'Positive' 
            WHEN sp.UpVotes < sp.DownVotes THEN 'Negative' 
            ELSE 'Neutral' 
        END AS Sentiment,
        ROW_NUMBER() OVER (PARTITION BY sp.Sentiment ORDER BY sp.Score DESC) AS SentimentRank
    FROM 
        SelectedPosts sp
)
SELECT 
    ph.PostId,
    ph.Title,
    ph.Level,
    pa.Score,
    pa.UpVotes,
    pa.DownVotes,
    pa.Sentiment,
    pa.SentimentRank,
    ubr.DisplayName AS MostActiveUser,
    ub.BadgeCount,
    ub.HighestBadgeClass
FROM 
    RecursivePostHierarchy ph
JOIN 
    PostAnalysis pa ON ph.PostId = pa.Id
LEFT JOIN 
    (SELECT 
        c.PostId,
        u.DisplayName,
        COUNT(c.Id) AS ActivityCount
     FROM 
        Comments c
     JOIN 
        Users u ON c.UserId = u.Id
     GROUP BY 
        c.PostId, u.DisplayName
     ORDER BY 
        ActivityCount DESC
    ) AS MostActive ON MostActive.PostId = pa.Id
LEFT JOIN 
    UserWithBadges ub ON MostActive.DisplayName = ub.DisplayName
WHERE 
    ph.Level <= 3  -- Limit the hierarchy depth
ORDER BY 
    ph.Level, pa.Score DESC;
