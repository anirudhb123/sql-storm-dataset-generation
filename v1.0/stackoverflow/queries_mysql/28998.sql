
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.LastActivityDate,
        p.AcceptedAnswerId,
        @row_number := CASE WHEN @prev_tag = p.Tags THEN @row_number + 1 ELSE 1 END AS RankPerTag,
        @prev_tag := p.Tags,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS JOIN (SELECT @row_number := 0, @prev_tag := '') AS init
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.Tags, p.CreationDate, p.LastActivityDate, p.AcceptedAnswerId, p.Score
),
TagSummary AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', numbers.n), '>', -1)) AS TagName,
        COUNT(*) AS PostCount,
        SUM(UpvoteCount - DownvoteCount) AS NetVotes
    FROM 
        RankedPosts
    INNER JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) AS numbers
    WHERE 
        RankPerTag = 1 
    GROUP BY 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', numbers.n), '>', -1))
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        NetVotes,
        @tag_ranking := @tag_ranking + 1 AS TagRanking
    FROM 
        TagSummary
    CROSS JOIN (SELECT @tag_ranking := 0) AS init
    ORDER BY 
        PostCount DESC, NetVotes DESC
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tt.NetVotes,
    rp.Title AS TopPostTitle,
    rp.OwnerDisplayName,
    rp.CreationDate
FROM 
    TopTags tt
JOIN 
    RankedPosts rp ON FIND_IN_SET(tt.TagName, rp.Tags)
WHERE 
    tt.TagRanking <= 5 
AND 
    rp.RankPerTag = 1 
ORDER BY 
    tt.TagRanking;
