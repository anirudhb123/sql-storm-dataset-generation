WITH PostSummaries AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        string_agg(t.TagName, ', ') AS Tags,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '>')::int[])
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id
),
MostVoted AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ps.Score,
        ps.AnswerCount,
        ps.CommentCount,
        ps.Tags,
        RANK() OVER (ORDER BY ps.Score DESC, ps.ViewCount DESC) AS Rank
    FROM 
        PostSummaries ps
),
TopPosts AS (
    SELECT 
        mp.PostId,
        mp.Title,
        mp.ViewCount,
        mp.Score,
        mp.AnswerCount,
        mp.CommentCount,
        mp.Tags
    FROM 
        MostVoted mp
    WHERE 
        mp.Rank <= 10 -- Top 10 voted questions
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        COUNT(DISTINCT c.Id) AS CommentsMade,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.QuestionsAsked,
        ue.CommentsMade,
        ue.UpVotes,
        ue.DownVotes,
        RANK() OVER (ORDER BY ue.UpVotes - ue.DownVotes DESC) AS UserRank
    FROM 
        UserEngagement ue
)
SELECT 
    t.Title AS TopPostTitle,
    t.ViewCount AS TopPostViewCount,
    t.Score AS TopPostScore,
    tu.DisplayName AS MostEngagedUser,
    tu.QuestionsAsked,
    tu.CommentsMade,
    tu.UpVotes,
    tu.DownVotes
FROM 
    TopPosts t
JOIN 
    TopUsers tu ON tu.UserRank = 1
ORDER BY 
    t.Score DESC;
