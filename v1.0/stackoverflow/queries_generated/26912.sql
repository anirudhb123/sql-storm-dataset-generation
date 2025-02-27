WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.Tags,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1  -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId, p.Tags
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        rp.AnswerCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS TotalUpVotes,  -- Upvotes
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS TotalDownVotes, -- Downvotes
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE -1 END), 0) AS NetVotes,
        STRING_AGG(t.TagName, ', ') AS TagsAggregated
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    LEFT JOIN 
        UNNEST(string_to_array(rp.Tags, ',')) AS t(TagName) ON TRUE
    WHERE 
        rp.rn = 1  -- Get the latest version of each question
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.CreationDate, u.DisplayName, rp.AnswerCount
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.OwnerDisplayName,
        ps.AnswerCount,
        ps.TotalUpVotes,
        ps.TotalDownVotes,
        ps.NetVotes,
        ps.TagsAggregated,
        ROW_NUMBER() OVER (ORDER BY ps.NetVotes DESC, ps.TotalUpVotes DESC) AS PostRank
    FROM 
        PostStatistics ps
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.AnswerCount,
    tp.TotalUpVotes,
    tp.TotalDownVotes,
    tp.NetVotes,
    tp.TagsAggregated
FROM 
    TopPosts tp
WHERE 
    tp.PostRank <= 10  -- Get the top 10 posts by net votes
ORDER BY 
    tp.NetVotes DESC;
