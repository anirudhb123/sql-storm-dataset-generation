WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(a.Id) AS AnswerCount,
        STRING_AGG(t.TagName, ', ') AS Tags,
        RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag_array ON true
    LEFT JOIN 
        Tags t ON t.TagName = tag_array
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        Tags
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 10
),
PostStatistics AS (
    SELECT 
        u.DisplayName AS UserDisplayName,
        u.Reputation,
        tp.Title AS PostTitle,
        tp.CreationDate,
        tp.Score,
        tp.AnswerCount,
        tp.Tags,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        TopRankedPosts tp
    JOIN 
        Users u ON u.Id = tp.OwnerUserId
    LEFT JOIN 
        Comments c ON c.PostId = tp.PostId
    LEFT JOIN 
        Votes v ON v.PostId = tp.PostId AND v.VoteTypeId IN (8, 9) -- Count only Bounties
    GROUP BY 
        u.DisplayName, 
        u.Reputation, 
        tp.Title, 
        tp.CreationDate, 
        tp.Score, 
        tp.AnswerCount, 
        tp.Tags
)
SELECT 
    UserDisplayName,
    Reputation,
    PostTitle,
    CreationDate,
    Score,
    AnswerCount,
    Tags,
    CommentCount,
    TotalBounty
FROM 
    PostStatistics
ORDER BY 
    Reputation DESC, Score DESC;
