WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        t.TagName,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.Score >= 10 -- Select only popular questions
),
PopularQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        rp.TagName
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5 -- Get top 5 posts per tag
),
RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= NOW() - INTERVAL '30 days' -- Recent comments
    GROUP BY 
        c.PostId
),
FinalResults AS (
    SELECT 
        pq.PostId,
        pq.Title,
        pq.Body,
        pq.CreationDate,
        pq.OwnerDisplayName,
        pq.TagName,
        COALESCE(rc.CommentCount, 0) AS CommentCount
    FROM 
        PopularQuestions pq
    LEFT JOIN 
        RecentComments rc ON pq.PostId = rc.PostId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.Body,
    fr.CreationDate,
    fr.OwnerDisplayName,
    fr.TagName,
    fr.CommentCount,
    CASE 
        WHEN fr.CommentCount > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS ActivityStatus
FROM 
    FinalResults fr
ORDER BY 
    fr.TagName,
    fr.Score DESC;
