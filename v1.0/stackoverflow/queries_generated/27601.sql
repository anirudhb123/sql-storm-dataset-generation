WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN bh.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseVotes,
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
        PostHistory bh ON p.Id = bh.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Author,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.CloseVotes,
        rp.PostRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1 -- Get only the latest post for each user
),
TagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(t.Id) AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.TagName = ANY (string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Author,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    fp.CloseVotes,
    tc.TagCount
FROM 
    FilteredPosts fp
LEFT JOIN 
    TagCounts tc ON fp.PostId = tc.PostId
ORDER BY 
    fp.UpVotes DESC, fp.CommentCount DESC; -- Order by most upvotes, then comments
