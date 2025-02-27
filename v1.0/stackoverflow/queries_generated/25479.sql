WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Body,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        
        -- Calculate the net score
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) - COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS NetScore,
        
        -- Generate a summary of the tags
        STRING_AGG(DISTINCT TRIM(BOTH '<>' FROM UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))), ', ') AS TagsSummary,
        
        ROW_NUMBER() OVER (ORDER BY COUNT(c.Id) DESC, NetScore DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate
),
TopPosts AS (
    SELECT 
        PostID,
        Title,
        Body,
        CreationDate,
        CommentCount,
        UpVoteCount,
        DownVoteCount,
        NetScore,
        TagsSummary
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10 -- Get top 10 posts based on comments and net score
)

SELECT 
    tp.PostID,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    tp.NetScore,
    tp.TagsSummary,
    
    -- Fetch user information for the owner of the post
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    u.Location AS OwnerLocation,
    
    -- Calculate the total time since the post was created
    EXTRACT(epoch FROM NOW() - tp.CreationDate) / 3600 AS HoursSinceCreation
    
FROM 
    TopPosts tp
JOIN 
    Users u ON u.Id = (
        SELECT OwnerUserId 
        FROM Posts 
        WHERE Id = tp.PostID
    )
ORDER BY 
    tp.NetScore DESC, tp.CommentCount DESC;
