
WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostTypeName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 30 DAY 
        AND p.ViewCount > 50
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.ViewCount, u.DisplayName, pt.Name
),

TagAggregates AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        FilteredPosts 
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1
    GROUP BY 
        TagName
),

RankedPosts AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.Body,
        fp.Tags,
        fp.CreationDate,
        fp.ViewCount,
        fp.OwnerDisplayName,
        fp.PostTypeName,
        fp.CommentCount,
        fp.UpVotes,
        fp.DownVotes,
        @rank := @rank + 1 AS Rank
    FROM 
        FilteredPosts fp, (SELECT @rank := 0) r
    ORDER BY 
        fp.ViewCount DESC, (fp.UpVotes - fp.DownVotes) DESC
)

SELECT 
    rp.*,
    ta.TagName,
    ta.PostCount
FROM 
    RankedPosts rp
LEFT JOIN 
    TagAggregates ta ON FIND_IN_SET(ta.TagName, rp.Tags)
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Rank, ta.PostCount DESC;
