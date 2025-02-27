WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByTag
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Selecting only Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Questions created in the last year
        AND p.Score > 0 -- Only questions with a positive score
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '>')) AS TagName,
        COUNT(*) AS NumberOfPosts
    FROM 
        Posts
    WHERE
        PostTypeId = 1 -- Only Questions
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 5 -- Only tags with more than 5 questions
),
TopTenPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerName,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        pt.Name AS PostTypeName,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC) AS OverallRanking
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON rp.PostId = pt.Id -- Use the proper PostTypeId
    WHERE 
        rp.RankByTag = 1 -- Keep only the highest rank per tag
)
SELECT 
    ttp.PostId,
    ttp.Title,
    ttp.OwnerName,
    ttp.Score,
    ttp.ViewCount,
    ttp.AnswerCount,
    ttp.CommentCount,
    pt.Name AS PostTypeName,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = ttp.PostId) AS TotalComments,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ttp.PostId AND v.VoteTypeId = 2) AS TotalUpVotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ttp.PostId AND v.VoteTypeId = 3) AS TotalDownVotes
FROM 
    TopTenPosts ttp
JOIN 
    PopularTags pt ON pt.TagName = ANY(string_to_array(substring(ttp.Title, 2, length(ttp.Title)-2), '>')) -- Joining to get popular tags
WHERE 
    ttp.OverallRanking <= 10 -- Top 10 questions
ORDER BY 
    ttp.Score DESC, ttp.ViewCount DESC; -- Order by Score and then by ViewCount
