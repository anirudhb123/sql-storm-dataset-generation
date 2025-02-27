WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS RankByTag
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    WHERE 
        p.PostTypeId = 1 -- We're only interested in Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        OwnerDisplayName,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        RankByTag = 1
),
TagCounts AS (
    SELECT 
        unnest(string_to_array(Tags, '<>')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
),
MostCommonTags AS (
    SELECT 
        Tag,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
)
SELECT 
    tp.Title,
    tp.Body,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.VoteCount,
    mct.Tag,
    mct.PostCount
FROM 
    TopPosts tp
JOIN 
    MostCommonTags mct ON tp.Tags LIKE '%' || mct.Tag || '%'
ORDER BY 
    mct.PostCount DESC, tp.VoteCount DESC
LIMIT 10;

This SQL query benchmarks string processing by analyzing posts from the `Posts` table based on their tags, filtering for questions only. It calculates ranks for posts based on their creation dates within each tag, counts the number of comments and votes for each question, and retrieves the top posts. Additionally, it finds the most common tags along with the posting activity count associated with those tags, combining this information into a final output that presents the most relevant and active posts along with their tag information.
