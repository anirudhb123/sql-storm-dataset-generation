WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT 
            Id, 
            Unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName 
         FROM 
            Posts) t ON p.Id = t.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.Id
)

SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(bp.BadgeCount, 0) AS BadgeCount,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Rank,
    CASE 
        WHEN rp.AcceptedAnswerId IS NOT NULL THEN 'Has Accepted Answer' 
        ELSE 'No Accepted Answer' 
    END AS AnswerStatus,
    string_agg(DISTINCT t.TagName, ', ') AS AssociatedTags
FROM 
    Users u
JOIN 
    RankedPosts rp ON u.Id = rp.PostId
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS BadgeCount 
     FROM Badges 
     GROUP BY UserId) bp ON u.Id = bp.UserId
LEFT JOIN 
    LATERAL (SELECT Unnest(rp.Tags) AS TagName) t ON true
WHERE 
    u.Reputation > (SELECT AVG(Reputation) FROM Users) 
    AND rp.Rank <= 5
GROUP BY 
    u.DisplayName, u.Reputation, rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.Rank
ORDER BY 
    rp.Score DESC, u.Reputation DESC;

WITH AnswerStats AS (
    SELECT 
        PostId, 
        COUNT(*) AS AnswerCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 2
    GROUP BY 
        PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS CloseReasonCount,
        STRING_AGG(DISTINCT c.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes c ON ph.Comment::INT = c.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    COALESCE(as.AnswerCount, 0) AS TotalAnswers,
    COALESCE(cp.CloseReasonCount, 0) AS CloseReasonCount,
    COALESCE(cp.CloseReasons, 'No closures') AS ClosureDetails
FROM 
    RankedPosts rp
LEFT JOIN 
    AnswerStats as ON rp.PostId = as.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Score DESC;

SELECT 
    p.Title,
    u.DisplayName,
    COALESCE(AVG(v.BountyAmount), 0) AS AvgBounty,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Id, u.DisplayName
HAVING 
    NULLIF(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) IS NOT NULL;

WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.BountyAmount) FILTER (WHERE v.VoteTypeId IN (8, 9)) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    ua.PostCount,
    ua.CommentCount,
    ua.Total
