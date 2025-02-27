WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ARRAY_AGG(t.TagName) AS TagsArray,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag_name ON TRUE
    LEFT JOIN 
        Tags t ON tag_name = t.TagName
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        Id,
        Title,
        Body,
        CreationDate,
        ViewCount,
        Score,
        OwnerDisplayName,
        TagsArray,
        CommentCount,
        UpVoteCount,
        DownVoteCount
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5 -- Limit to the latest 5 posts per user
)
SELECT 
    f.OwnerDisplayName,
    COUNT(*) AS QuestionCount,
    SUM(f.CommentCount) AS TotalComments,
    SUM(f.UpVoteCount) AS TotalUpVotes,
    SUM(f.DownVoteCount) AS TotalDownVotes,
    ARRAY_AGG(DISTINCT unnest(f.TagsArray)) AS AllUniqueTags
FROM 
    FilteredPosts f
GROUP BY 
    f.OwnerDisplayName
ORDER BY 
    QuestionCount DESC
LIMIT 10;
