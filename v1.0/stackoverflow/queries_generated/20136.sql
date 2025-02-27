WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownvoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
),
PostDetails AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.OwnerName,
        rp.PostRank,
        COALESCE(rp.UpvoteCount, 0) AS Upvotes,
        COALESCE(rp.DownvoteCount, 0) AS Downvotes,
        CASE 
            WHEN rp.Score IS NULL THEN 'No Score'
            WHEN rp.Score > 0 THEN 'Positive Score'
            ELSE 'Negative Score'
        END AS ScoreStatus
    FROM 
        RankedPosts rp
)
SELECT 
    pd.PostID,
    pd.Title,
    pd.ViewCount,
    pd.Score,
    pd.OwnerName,
    pd.PostRank,
    pd.Upvotes,
    pd.Downvotes,
    pd.ScoreStatus,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = pd.PostID AND ph.PostHistoryTypeId IN (10, 11)) AS CloseReopenCount
FROM 
    PostDetails pd
WHERE 
    pd.PostRank <= 5  -- Top 5 posts per type
ORDER BY 
    pd.Score DESC,
    pd.ViewCount DESC;

-- Handling NULL and edge cases
SELECT *
FROM Users u
LEFT JOIN (
    SELECT 
        p.OwnerUserId, 
        SUM(ph.CreationDate IS NOT NULL::int) AS PostHistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '6 months')
    GROUP BY 
        p.OwnerUserId
) uph ON u.Id = uph.OwnerUserId
WHERE 
    u.Reputation > 1000
    AND (uph.PostHistoryCount IS NULL OR uph.PostHistoryCount > 5);

-- Utilize string expressions to filter users with specific characteristics
SELECT 
    u.Id,
    CONCAT('User: ', u.DisplayName, ', Reputation: ', u.Reputation) AS UserInfo,
    COALESCE(u.Location, 'Location Unknown') AS UserLocation,
    CASE
        WHEN u.AboutMe IS NULL THEN 'No About Me Info'
        ELSE u.AboutMe
    END AS AboutMeDetails
FROM 
    Users u
WHERE 
    LOWER(u.Location) LIKE '%developer%'
    AND (u.CreationDate > '2022-01-01' OR u.Reputation BETWEEN 500 AND 1000)
ORDER BY 
    u.LastAccessDate DESC;

-- Aggregating information using set operators
SELECT 
    'Top Users From Posts' AS Source,
    u.DisplayName,
    COUNT(p.Id) AS PostCount
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
WHERE 
    u.Reputation >= 500
GROUP BY 
    u.DisplayName
UNION ALL
SELECT 
    'Top Users From Comments' AS Source,
    u.DisplayName,
    COUNT(c.Id) AS CommentCount
FROM 
    Users u
JOIN 
    Comments c ON u.Id = c.UserId
WHERE 
    u.EmailHash IS NOT NULL -- users with verified emails
GROUP BY 
    u.DisplayName
ORDER BY 
    PostCount DESC NULLS LAST, CommentCount DESC NULLS LAST;
