WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VoteCount, -- Makes a distinction between Upvotes and Downvotes
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistories AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        COUNT(*) OVER (PARTITION BY ph.PostId) AS HistoryCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Only including closed and reopened
),
ClosedPostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END), p.CreationDate) AS ClosedDate,
        COALESCE(MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END), p.CreationDate) AS ReopenedDate,
        p.ViewCount,
        p.Score,
        ph.HistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistories ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score
)
SELECT 
    u.DisplayName,
    up.QuestionCount,
    p.PostId,
    p.Title,
    p.ViewCount,
    p.Score,
    p.ClosedDate,
    p.ReopenedDate,
    CASE 
        WHEN p.ClosedDate IS NOT NULL THEN 
            DATEDIFF(day, p.ClosedDate, GETDATE()) 
        ELSE 
            NULL 
    END AS DaysSinceClosed,
    (SELECT STRING_AGG(t.TagName, ', ') 
     FROM STRING_SPLIT((SELECT Tags FROM Posts WHERE Id = p.PostId), ',') AS t) AS Tags
FROM 
    UserActivity up
JOIN 
    ClosedPostDetails p ON up.UserId = p.PostId -- Assuming we want users who commented on the closed posts
WHERE 
    up.VoteCount > 5
    AND p.Score > 10
ORDER BY 
    DaysSinceClosed DESC,
    up.CommentCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
