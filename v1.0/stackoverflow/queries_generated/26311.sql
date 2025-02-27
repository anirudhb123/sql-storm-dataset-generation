WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        ARRAY(SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) ORDER BY 1) AS TagList,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS NetVotes,  -- Net upvotes
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId  -- Answers to questions
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body
), FilteredTags AS (
    SELECT
        rp.PostId,
        rp.TagList,
        rp.NetVotes,
        rp.CommentCount,
        rp.AnswerCount,
        rp.Rank,
        STRING_AGG(DISTINCT t.TagName, ', ') AS FilteredTags  -- Concatenate distinct tags
    FROM
        RankedPosts rp
    JOIN
        Posts p ON rp.PostId = p.Id
    LEFT JOIN
        Tags t ON t.Id = ANY(rp.TagList)  -- Using the extracted tags
    WHERE
        t.Count > 10  -- Tags with more than 10 uses
    GROUP BY
        rp.PostId, rp.TagList, rp.NetVotes, rp.CommentCount, rp.AnswerCount, rp.Rank
)
SELECT 
    ft.PostId,
    ft.NetVotes,
    ft.CommentCount,
    ft.AnswerCount,
    ft.Rank,
    ft.FilteredTags
FROM 
    FilteredTags ft
WHERE
    ft.Rank <= 10  -- Top 10 questions
ORDER BY 
    ft.Rank;
