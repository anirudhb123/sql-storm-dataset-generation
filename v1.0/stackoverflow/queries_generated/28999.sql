WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.Score
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.Score,
        rp.AnswerCount,
        t.TagName AS MainTag,
        JSON_AGG(b.Name) AS UserBadges
    FROM 
        RankedPosts rp
    JOIN 
        Tags t ON t.Id = (
            SELECT MIN(t.Id) 
            FROM Tags t 
            WHERE t.TagName = ANY(string_to_array(rp.Tags, '><'))
        ) 
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.Tags, rp.CreationDate, rp.Score, rp.AnswerCount, t.TagName
),
PostStatistics AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.AnswerCount,
        fp.Score,
        fp.MainTag,
        fp.UserBadges,
        CASE 
            WHEN fp.AnswerCount > 0 THEN 'Active'
            ELSE 'Inactive'
        END AS PostStatus
    FROM 
        FilteredPosts fp
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.AnswerCount,
    ps.Score,
    ps.MainTag,
    ps.UserBadges,
    ps.PostStatus,
    COUNT(c.Id) AS CommentCount
FROM 
    PostStatistics ps
LEFT JOIN 
    Comments c ON c.PostId = ps.PostId
GROUP BY 
    ps.PostId, ps.Title, ps.CreationDate, ps.AnswerCount, ps.Score, ps.MainTag, ps.UserBadges, ps.PostStatus
ORDER BY 
    ps.Score DESC, ps.CreationDate DESC
LIMIT 50;
