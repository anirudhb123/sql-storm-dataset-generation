WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY v.CreationDate DESC) AS RecentVoteRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  -- Count only Upvotes
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.AnswerCount, p.CommentCount, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        Id,
        Title,
        Body,
        CreationDate,
        ViewCount,
        AnswerCount,
        CommentCount,
        OwnerDisplayName,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        RecentVoteRank = 1
    ORDER BY 
        VoteCount DESC
    LIMIT 10
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        LATERAL (
            SELECT 
                TRIM(UNNEST(string_to_array(substring(p.Tags, 2, LENGTH(p.Tags) - 2), '><'))) ) AS TagName
            ) t ON true
    GROUP BY 
        p.Id
)
SELECT 
    fp.Id AS PostId,
    fp.Title,
    fp.Body,
    fp.CreationDate,
    fp.ViewCount,
    fp.AnswerCount,
    fp.CommentCount,
    fp.OwnerDisplayName,
    fp.VoteCount,
    pt.Tags
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostTags pt ON fp.Id = pt.PostId
ORDER BY 
    fp.VoteCount DESC, fp.CreationDate DESC;
