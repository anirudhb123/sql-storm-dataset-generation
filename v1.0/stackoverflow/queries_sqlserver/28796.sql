
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        COALESCE(u.DisplayName, 'Community User') AS OwnerName,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS APPLY (
        SELECT 
            value AS TagName
        FROM 
            STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags)-2), '>.<')
    ) AS t 
    WHERE 
        p.PostTypeId = 1 AND  
        p.Score > 0 AND       
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.AnswerCount, p.Score, u.DisplayName
),
PostEngagement AS (
    SELECT 
        rp.PostId,
        rp.OwnerName,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId AND v.VoteTypeId IN (2, 3)  
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT TOP 1 OwnerUserId FROM Posts WHERE Id = rp.PostId)
    GROUP BY 
        rp.PostId, rp.OwnerName, rp.Title, rp.CreationDate, rp.ViewCount, rp.AnswerCount, rp.Score
),
FinalResults AS (
    SELECT 
        pe.*,
        CASE 
            WHEN HighestBadgeClass = 1 THEN 'Gold'
            WHEN HighestBadgeClass = 2 THEN 'Silver'
            WHEN HighestBadgeClass = 3 THEN 'Bronze'
            ELSE 'None'
        END AS BadgeStatus,
        CASE 
            WHEN AnswerCount > 5 THEN 'Highly Engaging'
            WHEN ViewCount > 100 THEN 'Popular'
            ELSE 'Average Engagement'
        END AS EngagementLevel
    FROM 
        PostEngagement pe
)
SELECT 
    PostId,
    OwnerName,
    Title,
    CreationDate,
    ViewCount,
    AnswerCount,
    Score,
    CommentCount,
    VoteCount,
    BadgeStatus,
    EngagementLevel
FROM 
    FinalResults
ORDER BY 
    Score DESC, ViewCount DESC, CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
