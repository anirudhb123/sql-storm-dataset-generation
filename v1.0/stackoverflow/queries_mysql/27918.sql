
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId IN (10, 11) THEN 1 ELSE 0 END) AS TotalClosures,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostDetail AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        GROUP_CONCAT(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', n.n), '<', -1) SEPARATOR ', ') AS ExtractedTags,
        COALESCE(phh.Comment, 'No closure reason') AS ClosureReason
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory phh ON p.Id = phh.PostId AND phh.PostHistoryTypeId = 10
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= n.n - 1
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate
),
RankedPosts AS (
    SELECT 
        pd.*,
        @rownum := @rownum + 1 AS Rank
    FROM 
        PostDetail pd, (SELECT @rownum := 0) r
    ORDER BY 
        pd.ViewCount DESC
)
SELECT 
    us.DisplayName,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.TotalClosures,
    us.TotalUpvotes,
    us.TotalDownvotes,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    rp.ExtractedTags,
    rp.ClosureReason,
    rp.Rank
FROM 
    UserStats us
JOIN 
    RankedPosts rp ON us.UserId = rp.PostId
WHERE 
    us.TotalQuestions > 0
ORDER BY 
    us.TotalUpvotes DESC,
    rp.Rank;
