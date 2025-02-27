WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL
        AND p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
),
PostWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        b.Name AS BadgeName,
        CASE 
            WHEN b.Class = 1 THEN 'Gold'
            WHEN b.Class = 2 THEN 'Silver'
            ELSE 'Bronze'
        END AS BadgeClass
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    WHERE 
        b.Date >= (CURRENT_DATE - INTERVAL '2 years')
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate < (CURRENT_DATE - INTERVAL '6 months')
        AND ph.Comment IS NOT NULL
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(ph.Comment, 'No comment') AS CloseComment,
        COUNT(*) AS CloseCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistoryDetails ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    GROUP BY 
        p.Id, CloseComment
)

SELECT 
    p.Title,
    p.ViewCount,
    STRING_AGG(b.BadgeName, ', ') AS UserBadges,
    cp.CloseCount,
    CASE 
        WHEN cp.CloseCount > 0 THEN CONCAT('Closed with comment: ', cp.CloseComment)
        ELSE 'Not closed'
    END AS ClosureStatus,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags,
    CASE 
        WHEN COUNT(v.Id) > 0 THEN SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE -1 END)
        ELSE 0
    END AS TotalVotes,
    COUNT(DISTINCT c.Id) AS CommentCount
FROM 
    Posts p
LEFT JOIN 
    PostWithBadges b ON b.PostId = p.Id
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = p.Id
LEFT JOIN 
    Tags t ON t.Id IN (SELECT UNNEST(string_to_array(p.Tags, '><'))::int) FROM Posts)
LEFT JOIN 
    Votes v ON v.PostId = p.Id
LEFT JOIN 
    Comments c ON c.PostId = p.Id
WHERE 
    p.AnswerCount > 0
GROUP BY 
    p.Title, p.ViewCount, cp.CloseCount, cp.CloseComment
ORDER BY 
    p.ViewCount DESC,
    TotalVotes DESC
LIMIT 100;
