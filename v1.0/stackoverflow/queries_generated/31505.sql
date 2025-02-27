WITH RecursiveCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        rn
    FROM 
        Posts p
    JOIN 
        RecursiveCTE r ON p.ParentId = r.Id
),
FilteredPosts AS (
    SELECT 
        r.Id,
        r.Title,
        u.DisplayName AS Author,
        r.CreationDate,
        r.Score, 
        COALESCE(POST.downvote_count, 0) AS DownVotes,
        COALESCE(POST.upvote_count, 0) AS UpVotes
    FROM 
        RecursiveCTE r
    LEFT JOIN 
        Users u ON r.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS upvote_count,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS downvote_count
        FROM 
            Votes
        GROUP BY 
            PostId
    ) AS POST ON r.Id = POST.PostId
    WHERE 
        r.rn = 1  -- Get the latest question for each user
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(*) AS TagCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    ORDER BY 
        TagCount DESC
    LIMIT 5
)
SELECT 
    fp.Id AS PostID,
    fp.Title,
    fp.Author,
    fp.CreationDate,
    fp.Score,
    fp.UpVotes,
    fp.DownVotes,
    STRING_AGG(pt.TagName, ', ') AS PopularTags
FROM 
    FilteredPosts fp
LEFT JOIN 
    PopularTags pt ON pt.TagName IN (
        SELECT 
            TRIM(UNNEST(STRING_TO_ARRAY(fp.Title, ' ')))  -- Example tag extraction logic
    )
GROUP BY 
    fp.Id, fp.Title, fp.Author, fp.CreationDate, fp.Score, fp.UpVotes, fp.DownVotes
ORDER BY 
    fp.Score DESC
FETCH FIRST 10 ROWS ONLY;
