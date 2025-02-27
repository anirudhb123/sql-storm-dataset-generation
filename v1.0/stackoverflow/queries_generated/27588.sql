WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        u.Reputation AS AuthorReputation,
        COUNT(c.Id) AS CommentCount,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 
                (SELECT COUNT(*) 
                 FROM Votes v 
                 WHERE v.PostId = p.AcceptedAnswerId AND v.VoteTypeId = 2) -- Upvotes
            ELSE 0
        END AS AcceptedAnswerUpvotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 YEAR'
        AND p.PostTypeId = 1 -- Question
    GROUP BY 
        p.Id, u.DisplayName, u.Reputation
),
TagStatistics AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        RankedPosts
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS Rank
    FROM 
        TagStatistics
),
TopPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Author,
        rp.AuthorReputation,
        rp.CreationDate,
        rp.CommentCount,
        COALESCE(tt.TagName, 'No Tags') AS MostUsedTag,
        rp.AcceptedAnswerUpvotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        TopTags tt ON tt.Rank = 1
    ORDER BY 
        rp.Score DESC, rp.ViewCount DESC
    LIMIT 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.Author,
    tp.AuthorReputation,
    TO_CHAR(tp.CreationDate, 'YYYY-MM-DD HH24:MI:SS') AS CreatedOn,
    tp.CommentCount,
    tp.MostUsedTag,
    tp.AcceptedAnswerUpvotes
FROM 
    TopPosts tp

