WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        u.DisplayName as OwnerDisplayName,
        DENSE_RANK() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) as TagRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        OwnerDisplayName,
        Tags,
        UpVotes,
        DownVotes,
        CommentCount,
        ROW_NUMBER() OVER (PARTITION BY Tags ORDER BY UpVotes DESC) as UpVoteRank
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5 AND CommentCount > 0  -- Only top 5 ranked tags with comments
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.OwnerDisplayName,
    fp.Tags,
    fp.UpVotes,
    fp.DownVotes,
    fp.CommentCount,
    REPLACE(SUBSTRING(fp.Tags, 2, LENGTH(fp.Tags) - 2), '><', ', ') AS FormattedTags,
    CASE 
        WHEN fp.UpVoteRank = 1 THEN 'Top Post'
        ELSE 'Regular Post' 
    END AS PostCategory
FROM 
    FilteredPosts fp
ORDER BY 
    fp.CreationDate DESC, fp.UpVotes DESC;
