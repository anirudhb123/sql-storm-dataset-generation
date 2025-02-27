WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Last year
),
TopQuestions AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        OwnerReputation
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 -- Top 5 per user
),
UserBadges AS (
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
VotesStats AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id
)
SELECT 
    tq.PostId,
    tq.Title,
    tq.ViewCount,
    tq.OwnerReputation,
    COALESCE(b.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN tq.ViewCount > 100 THEN 'Highly Viewed'
        WHEN tq.ViewCount BETWEEN 50 AND 100 THEN 'Moderately Viewed'
        ELSE 'Less Viewed' 
    END AS ViewCategory
FROM 
    TopQuestions tq
LEFT JOIN 
    Users u ON tq.OwnerReputation = u.Reputation
LEFT JOIN 
    UserBadges b ON u.Id = b.UserId
LEFT JOIN 
    VotesStats vs ON tq.PostId = vs.PostId
ORDER BY 
    tq.ViewCount DESC,
    tq.OwnerReputation DESC;

