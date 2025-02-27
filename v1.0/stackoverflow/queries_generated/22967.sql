WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews,
        COUNT(v.VoteTypeId) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.VoteTypeId) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag_name ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_name
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id
),
LatestBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date >= NOW() - INTERVAL '1 year'
    GROUP BY 
        b.UserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(rp.RankByViews, 0) AS UserPostRank,
        COALESCE(lb.BadgeNames, 'No Badges') AS Badges,
        (u.UpVotes - u.DownVotes) AS ReputationScore
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.PostId
    LEFT JOIN 
        LatestBadges lb ON u.Id = lb.UserId
)
SELECT 
    u.DisplayName,
    u.ReputationScore,
    u.Badges,
    COUNT(*) FILTER (WHERE p.AcceptedAnswerId IS NOT NULL) AS AcceptedAnswers,
    SUM(p.ViewCount) AS TotalViews,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    ANY(p.Title) FILTER (WHERE p.CreationDate = (
        SELECT MAX(CreationDate) 
        FROM Posts p2 
        WHERE p2.OwnerUserId = u.Id
    )) AS MostRecentPostTitle,
    MAX(COALESCE(p.LastActivityDate, p.CreationDate)) AS LastActiveDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON p.OwnerUserId = u.Id
GROUP BY 
    u.Id, u.DisplayName, u.ReputationScore, u.Badges
HAVING 
    SUM(p.ViewCount) > 1000 
    AND COUNT(DISTINCT p.Id) > 5
ORDER BY 
    u.ReputationScore DESC, TotalViews DESC
LIMIT 10 OFFSET 0;

-- Unique clauses for performance benchmarking that check for NULLs and corner cases:
SELECT 
    p.OwnerUserId,
    COUNT(CASE WHEN p.AcceptedAnswerId IS NULL THEN 1 END) AS UnansweredQuestions,
    COUNT(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 END) AS ClosedQuestions,
    SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- Bounty Start and Bounty Close
WHERE 
    p.PostTypeId = 1 -- Questions only
GROUP BY 
    p.OwnerUserId
HAVING 
    COUNT(p.Id) > 5 
    AND SUM(COALESCE(v.BountyAmount, 0)) > 0;
