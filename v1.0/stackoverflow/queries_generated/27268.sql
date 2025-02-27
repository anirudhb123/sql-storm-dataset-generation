WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        string_agg(t.TagName, ', ') AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COALESCE(MAX(b.Class), 0) AS HighestBadgeClass
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
),
PostActivity AS (
    SELECT 
        PostId,
        COUNT(*) AS ActivityCount,
        MAX(LastActivityDate) AS LastActivity
    FROM 
        Posts
    GROUP BY 
        PostId
),
FinalBenchmark AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.Tags,
        rp.CommentCount,
        rp.AnswerCount,
        pa.ActivityCount,
        pa.LastActivity,
        CASE 
            WHEN rp.HighestBadgeClass = 1 THEN 'Gold'
            WHEN rp.HighestBadgeClass = 2 THEN 'Silver'
            WHEN rp.HighestBadgeClass = 3 THEN 'Bronze'
            ELSE 'No Badge'
        END AS BadgeStatus
    FROM 
        RankedPosts rp
    JOIN 
        PostActivity pa ON rp.PostId = pa.PostId
    ORDER BY 
        rp.Score DESC, 
        rp.ViewCount DESC,
        pa.ActivityCount DESC
    LIMIT 100
)
SELECT 
    *,
    CASE 
        WHEN AnswerCount > 0 THEN 'Answered'
        ELSE 'Unanswered'
    END AS PostStatus
FROM 
    FinalBenchmark;
