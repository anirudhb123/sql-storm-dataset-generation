WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COUNT(v.Id) AS VoteCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(v.Id) DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 6) -- Counting UpVotes and Close votes only
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags
),
FilteredRankedPosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.Body,
        r.Tags,
        r.VoteCount,
        r.CommentCount
    FROM 
        RankedPosts r
    WHERE 
        r.UserRank <= 10 -- Top 10 posts per user
),
TagStats AS (
    SELECT 
        UNNEST(string_to_array(Trim(both '<>' FROM Tags), '> <')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        FilteredRankedPosts
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        SUM(TagCount) AS TotalCount
    FROM 
        TagStats
    GROUP BY 
        TagName
    ORDER BY 
        TotalCount DESC
    LIMIT 5 -- Top 5 Tags
)

SELECT 
    fp.Title,
    fp.Body,
    fp.VoteCount,
    fp.CommentCount,
    tt.TagName,
    tt.TotalCount
FROM 
    FilteredRankedPosts fp
JOIN 
    TopTags tt ON fp.Tags LIKE '%' || tt.TagName || '%'
ORDER BY 
    fp.VoteCount DESC, 
    fp.CommentCount DESC;
